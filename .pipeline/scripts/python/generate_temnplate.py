import argparse
import sys
from jinja2 import Environment, FileSystemLoader


def generate_sample_html(template_folder: str, output_folder: str, number: int):
    environment = Environment(loader=FileSystemLoader(f"{template_folder}/"))
    template = environment.get_template("sample.html.j2")
    for i in range(0, number):
        filename = f"sample_{i}.html"
        content = template.render(number=i,
                                  total_samples=number)
        with open(f"{output_folder}/{filename}", "w", encoding="utf=8") as html:
            html.write(content)


def generate_index(template_folder: str, output_folder: str, num_sample_links: int):
    environment = Environment(loader=FileSystemLoader(f"{template_folder}/"))
    template = environment.get_template("index.html.j2")
    filename = "index.html"
    print(num_sample_links)
    content = template.render(number=num_sample_links)
    with open(f"{output_folder}/{filename}", "w", encoding="utf=8") as html:
        html.write(content)


def argument_parser() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="generate_template.py",
                                     description="Use Jinja2 Templates to create files")
    parser.add_argument("--sample-html",
                        action=argparse.BooleanOptionalAction,
                        default=False,
                        required=False,
                        metavar="Sample HTML",
                        type=bool,
                        help="Create the Sample HTML Pages from the J2 template")
    parser.add_argument("--sample-html-output-folder",
                        action="store",
                        required='--sample-html' in sys.argv,
                        metavar="Sample HTML Output Folder",
                        type=str,
                        help="Output folder for the sample html pages")
    parser.add_argument("--sample-html-number",
                        action="store",
                        required='--sample-html' in sys.argv,
                        metavar="Sample HTML Number",
                        type=int,
                        help="Number of Sample HTML Pages to create")
    parser.add_argument("--index-html",
                        action=argparse.BooleanOptionalAction,
                        default=False,
                        required=False,
                        metavar="Index HTML",
                        type=bool,
                        help="Create the Index HTML Page from the J2 template")
    parser.add_argument("--index-html-output-folder",
                        action="store",
                        required='--index-html' in sys.argv,
                        metavar="Index HTML Output Folder",
                        type=str,
                        help="Output folder for the index html page")
    parser.add_argument("--num-sample-links",
                        action="store",
                        required='--index-html' in sys.argv,
                        metavar="Index Sample Links",
                        type=int,
                        help="Number of links to the Sample HTML Pages")
    parser.add_argument("--template-folder",
                        action="store",
                        required=True,
                        metavar="Template Root Folder",
                        type=str,
                        nargs="?",
                        help="Path to the root of the template folder")
    return parser.parse_args()


if __name__ == "__main__":
    args = argument_parser()
    match True:
        case args.sample_html:
            generate_sample_html(template_folder=args.template_folder,
                                 output_folder=args.sample_html_output_folder,
                                 number=args.sample_html_number)
        case args.index_html:
            generate_index(template_folder=args.template_folder,
                           output_folder=args.index_html_output_folder,
                           num_sample_links=args.num_sample_links)
        case _:
            print("Nothing to do!!")
