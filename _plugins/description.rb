module CategoryDescriptionPlugin

    class Generator < Jekyll::Generator

        def generate(site)

            categoryDes = site.data['seo']['categories']
            pages = site.pages.select {|p| p.dir.include? "categories" }

            pages.each do |p| 
                categoryDes.each do |c| 
                    if p.name == c['name']
                        p.description = c['description']
                    end
                end
            end

        end

    end

end