{
  disko.devices = {

    disk = {

      main = {

        type = "disk";

        device = "/dev/sda";


        content = {

          type = "gpt";


          partitions = {

            BIOS-boot = {

              priority = 1;

              size = "1M";

              type = "EF02";

            };


            ESP = {

              priority = 2;

              size = "512M";

              type = "EF00";


              content = {

                type = "filesystem";

                format = "vfat";

                mountpoint = "/boot";

              };

            };


            root = {

              priority = 3;

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
