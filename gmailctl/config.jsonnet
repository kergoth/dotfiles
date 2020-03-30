local lib = import 'gmailctl.libsonnet';
{
  version: "v1alpha3",
  author: {
    name: "Christopher Larson",
    email: "kergoth@gmail.com"
  },
  // Note: labels management is optional. If you prefer to use the
  // GMail interface to add and remove labels, you can safely remove
  // this section of the config.
  labels: [
    {
      name: "Patches",
      color: {
        background: "#16a765",
        text: "#ffffff"
      }
    },
    {
      name: "Projects"
    },
    {
      name: "Projects/BitBake",
      color: {
        background: "#eeeeee",
        text: "#222222"
      }
    },
    {
      name: "Projects/OE",
      color: {
        background: "#fb4c2f",
        text: "#ffffff"
      }
    },
    {
      name: "Projects/Yocto",
      color: {
        background: "#eeeeee",
        text: "#222222"
      }
    },
    {
      name: "Reference"
    },
    {
      name: "Wedding"
    },
    {
      name: "Discounts"
    },
    {
      name: "Articles"
    },
    {
      name: "To Read"
    },
    {
      name: "Notes"
    },
    {
      name: "Rental Property"
    },
    {
      name: "Projects/Isar",
      color: {
        background: "#4986e7",
        text: "#ffffff"
      }
    },
    {
      name: "Releases"
    },
    {
      name: "Job Prospects"
    }
  ],
  rules: [
  ]
}
