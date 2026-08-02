{
  disko.devices = {

    disk = {

      main = {

        type = "disk";

        device = "/dev/sda";


        content = {

          type = "gpt";


          partitions = {

            ESP = {

              priority = 1;

              size = "512M";

              type = "EF00";


              content = {

                type = "filesystem";

                format = "vfat";

                mountpoint = "/boot";

              };

            };


            root = {

              priority = 2;

              size = "100%";


              content = {

                type = "filesystem";

                format = "ext4";

                mountpoint = "/";

              };

            };

          };

        };

      };

    };

  };
}
