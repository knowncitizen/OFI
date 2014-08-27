# encoding: utf-8
module Staypuft
  class Deployment::CinderService < Deployment::AbstractParamScope
    def self.param_scope
      'cinder'
    end

    BACKEND_TYPE_PARAMS = :backend_eqlx, :backend_nfs, :backend_lvm, :backend_ceph
    BACKEND_PARAMS = :nfs_uri, :rbd_secret_uuid

    param_attr *BACKEND_TYPE_PARAMS, *BACKEND_PARAMS
    param_attr_array :eqlx

    after_save :set_lvm_ptable


    module DriverBackend
      LVM        = 'lvm'
      NFS        = 'nfs'
      CEPH       = 'ceph'
      EQUALLOGIC = 'equallogic'
      LABELS     = { LVM        => N_('LVM'),
                     NFS        => N_('NFS'),
                     CEPH       => N_('Ceph'),
                     EQUALLOGIC => N_('EqualLogic') }
      TYPES      = LABELS.keys
      HUMAN      = N_('Choose Driver Backend')
    end
    validate :at_least_one_backend_selected

    module NfsUri
      HUMAN       = N_('NFS URI:')
      HUMAN_AFTER = Deployment::GlanceService::NFS_HELP
    end
    validates :nfs_uri,
              :presence => true,
              :if       => :nfs_backend?
    # TODO: uri validation

    module SanIp
      HUMAN       = N_('SAN IP Addr:')
    end
    module SanLogin
      HUMAN       = N_('SAN Login:')
    end
    module SanPassword
      HUMAN       = N_('SAN Password:')
    end
    module EqlxPool
      HUMAN       = N_('Pool:')
    end
    module EqlxGroupName
      HUMAN       = N_('Group:')
    end
    validates :eqlx,
              :presence   => true,
              :if         => :equallogic_backend?,
              :equallogic => true

    class Jail < Safemode::Jail
      allow :lvm_backend?, :nfs_backend?, :ceph_backend?, :equallogic_backend?,
        :rbd_secret_uuid, :nfs_uri, :eqlx
    end

    def set_defaults
      self.backend_lvm = "false"
      self.backend_ceph = "false"
      self.backend_nfs = "false"
      self.backend_eqlx = "false"
      self.rbd_secret_uuid = SecureRandom.uuid
    end

    # cinder config always shows up
    def active?
      true
    end

    def lvm_backend?
      !self.deployment.ha? && self.backend_lvm == "true"
    end

    def nfs_backend?
      self.backend_nfs == "true"
    end

    def ceph_backend?
      self.backend_ceph == "true"
    end

    def equallogic_backend?
      self.backend_eqlx == "true"
    end

    # view should use this rather than DriverBackend::LABELS to hide LVM for HA.
    def backend_labels_for_layout
      ret_list = DriverBackend::LABELS.clone
      ret_list.delete(DriverBackend::LVM) if self.deployment.ha?
      ret_list
    end
    def backend_types_for_layout
      ret_list = DriverBackend::TYPES.clone
      ret_list.delete(DriverBackend::LVM) if self.deployment.ha?
      ret_list
    end

    def param_hash
      { "backend_lvm" => backend_lvm, "backend_ceph" => backend_ceph,
        "backend_nfs" => backend_nfs, "backend_eqlx" => backend_eqlx,
        "nfs_uri" => nfs_uri, "rbd_secret_uuid" => rbd_secret_uuid,
        "eqlx" => eqlx }
    end

    def lvm_ptable
      Ptable.find_by_name('LVM with cinder-volumes')
    end

    private

    def set_lvm_ptable
      if (hostgroup = deployment.controller_hostgroup)
        ptable = lvm_ptable
       if (lvm_backend? && ptable.nil?)
          Rails.logger.error "Missing Partition Table 'LVM with cinder-volumes'"
        end
        if (lvm_backend? && ptable)
          hostgroup.ptable = ptable
        else
          hostgroup.ptable = nil
        end
        hostgroup.save!
      end
    end

    def at_least_one_backend_selected
      params = BACKEND_TYPE_PARAMS.clone
      if self.deployment.ha?
        params.delete :backend_lvm
      end
      unless params.detect(false) { |field| field }
        errors[:base] << _("At least one storage backend must be selected")
      end
    end

  end
end
