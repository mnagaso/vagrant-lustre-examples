# Cluster Examples with Vagrant

## Prerequisites

* [Vagrant](https://www.vagrantup.com/)     - Version tested: 2.2.14
* [VirtualBox](https://www.virtualbox.org/) - Version tested: 6.1.30

## Examples

* [lustre](lustre/)


## Workaround for VirtualBox7.1 

To use virtualbox 7.1, a small modification is necessary until updates of vagrant (as v7.1 is not supported yet.) 
ref: https://github.com/hashicorp/vagrant/issues/13501#issuecomment-2346267062

Edit /usr/bin/VBox to modify between #### #####

```diff
--- /tmp/orig/VBox	2024-09-14 15:40:52.961690431 +0200
+++ /usr/bin/VBox	2024-09-14 15:42:05.941525049 +0200
@@ -142,7 +142,11 @@
         exec "$INSTALL_DIR/VirtualBoxVM" "$@"
         ;;
     VBoxManage|vboxmanage)
-        exec "$INSTALL_DIR/VBoxManage" "$@"
+	if [[ $@ == "--version" ]]; then
+	  echo "7.0.0r164728"
+	else
+          exec "$INSTALL_DIR/VBoxManage" "$@"
+	fi
         ;;
     VBoxSDL|vboxsdl)
         exec "$INSTALL_DIR/VBoxSDL" "$@"
```