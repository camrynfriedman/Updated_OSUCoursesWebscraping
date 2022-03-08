require 'mechanize'
require 'json'
require 'yaml'

class Course
    attr_reader :title, :subCat, :description, :teach, :maxCH, :minCH, :room, :classNum, :section
    def initialize(title, subCat, description, teach, maxCH, minCH, room, classNum, section)
        @title = title
        @subCat = subCat
        @description = description
        @teach = teach
        @maxCH = maxCH
        @minCH = minCH
        @room = room
        @classNum = classNum
        @section = section
    end
end

class Scraper
	attr_accessor :url, :coursePages, :courseCatalog

	# Created, immplemented, tested on 02/29/2022 by Yifan Zhou
	def initialize
		@url = "https://content.osu.edu/v2/classes/search"
        @initial_query = "?q=cse&campus=col&term=1224&p=1"
        # An hashtable <<int>page_num: <hashTable>courses_data>, stores all the data about course
        @coursePages = {}

        @courseCatalog = []
        # menu_html = Nokogiri::HTML(menu['panels'][0]['html'])
        # course_content = json_data["data"]['courses'][0]["course"]["term"]
	end

    # Taking page_num as input, and store the result in courses
    def store_all_courses_page()
        puts "===> Start scraping all courses info..."
        page_num = 1
        agent = Mechanize.new       # Instantiate a Mechanize object
        puts "Initial page request: " + @url + @initial_query
        html_data = agent.get(@url + @initial_query)
        
        # rescue Mechanize::ResponseReadError => e
        json_data = JSON.parse html_data.body
        # Get total number of pages
        totalPages = json_data["data"]["totalPages"]
        # Store current page data
        @coursePages[page_num] = json_data["data"]['courses']
        get_course_info(page_num)

        while json_data["data"]["nextPageLink"] != nil
            page_num += 1
            sleep(2)
            puts "Getting Page #{page_num}: " + @url + json_data["data"]["nextPageLink"]
            html_data = agent.get(@url + json_data["data"]["nextPageLink"])
            json_data = JSON.parse html_data.body
            @coursePages[page_num] = json_data["data"]['courses']
            get_course_info(page_num)
        end

        puts "===> Finished scraping!"
        puts "===> Total pages: #{totalPages}"
        return totalPages
    end

    # Collecting the useful information about each courses in page_num
    def get_course_info(page_num)
        @coursePages[page_num].each do |item| # for each things in things do something while storing that things in the variable item
            # print "#{item}"
            newTitle = item["course"]["title"]
            newSubCat = item["course"]["subject"] + item["course"]["catalogNumber"]
            newDesc = item["course"]["description"]
            newMaxCH = item["course"]["maxUnits"]
            newMinCH = item["course"]["minUnits"]
            item["sections"].each do |section|
                @courseCatalog["#{newSubCat}_#{section["classNumber"]}"] = {
                    "title": newTitle, 
                    "subCat": newSubCat,
                    "description": newDesc,
                    "course_number": section["classNumber"],
                    "section": section["section"],
                    "instructor": section["meetings"][0]["instructors"][0]["displayName"],
                    "room": section["meetings"][0]["room"]
                }


            end
        end
    end

    def pretty_print(page_num)
		puts "A exaustive list of courses in #{page_num}!"
		@courseCatalog.each_with_index do |item, index|
			# puts name.class
			puts "#{index}; Course Number: #{item.subCat}; Course Title: #{item.title}"
		end
	end 

end



@scraper = Scraper.new
totalPages = @scraper.store_all_courses_page()

for i in 1..totalPages
    @scraper.get_course_info(i)
end
File.open "../data/course.yml", "w" do |file|
file << @scraper.courseCatalog.to_yaml
end


