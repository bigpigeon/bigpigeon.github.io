module Jekyll
  class MarkdownBlock < Liquid::Block
    def initialize(tag_name, text, tokens)
      super
    end
    require "redcarpet"
    def render(context)
      content = super
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, highlighter: true, fenced_code_blocks: true)
      "#{markdown.render(content)}"
    end
  end


end



Liquid::Template.register_tag('markdown', Jekyll::MarkdownBlock)