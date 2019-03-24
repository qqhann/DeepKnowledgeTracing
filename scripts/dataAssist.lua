require 'csvigo'
require 'util'
require 'string'
local class = require 'class'

DataAssistMatrix = class.new('DataAssistMatrix')

local max_train = nil
local max_steps = nil

-- Function: Get Data
-- Reads a CSV in standard feature format. Each row is a student
-- and each col is the score for the student on the
-- corresponding item.
function DataAssistMatrix:__init(params) 
	print('Loading khan...')
	--=====
	--train
	--=====
	local root = '../data/assistments/'
	local trainPath = root .. 'builder_train.csv'
	local file = io.open(trainPath, "rb")
	io.input(file)
	local count = 0
	local trainData = {}
	local longest = 0

	self.questions = {}
	self.n_questions = 0
	local totalAnswers = 0
	while(true) do
		local student = self:loadStudent()
		if(student == nil) then 
		    break 
		end
		if(student['n_answers'] >= 2) then -- 回答数が2以上の時
			table.insert(trainData, student) -- studentをtrainDataに挿入
		end -- elseはない。つまり、回答数が1のものを排除している
		if(#trainData % 100 == 0) then -- 100区切りで標準出力に進捗表示
		    print(#trainData)
		end
		if(student['n_answers'] > longest) then -- 回答数が多すぎる場合
			longest = student['n_answers'] -- 最長記録を更新
		end
		totalAnswers = totalAnswers+ student['n_answers']
	end

	self.trainData = trainData -- trainDataをインスタンス変数に保存
	io.close()

	--====
	--test
	--====
	local testPath = root .. 'builder_test.csv'
	local testFile = io.open(testPath, "rb")
	io.input(testFile)
	local count = 0
	local testData = {}

	self.questions = {}
	while(true) do
		local student = self:loadStudent()
		if(student == nil) then 
		    break 
		end
		if(student['n_answers'] >= 2) then
			table.insert(testData, student)
		end
		if(#testData % 100 == 0) then
		    print(#testData)
		end
		if(student['n_answers'] > longest) then
			--longest = student['n_answers']
		end
		totalAnswers = totalAnswers+ student['n_answers']
	end

	self.testData = testData
	io.close()
	print('total answers', totalAnswers)
	print('longest', longest)
end

function DataAssistMatrix:loadStudent()
	-- builder_train.csvを3行ずつ読む
	local nStepsStr = io.read() -- 1行目 1
	local questionIdStr = io.read() -- 2行目7
	local correctStr = io.read() -- 3行目 1
	if(nStepsStr == nil or questionIdStr == nil or correctStr == nil) then
		return nil
	end

	local n = tonumber(nStepsStr)
	if(max_steps ~= nil) then
		n = max_steps
	end 

	local student = {} -- 辞書型かな
	student['questionId'] = torch.zeros(n):byte() -- 問題番号のベクトル
	for i,id in ipairs(split(questionIdStr, ",")) do -- ","をsplitして処理している
		if(i > n) then
			break
		end
	    student['questionId'][i] = tonumber(id) + 1
	    if self.questions[id] == nil then -- 処理済みのをself.questionsに登録している
		self.questions[id] = true
	        self.n_questions = self.n_questions + 1 -- ある問題が何回登場したか数えている
	    end
	
	end

	student['correct'] = torch.zeros(n):byte() -- n長のベクトル？
	for i, val in ipairs(split(correctStr, ",")) do -- ","をsplitして処理している
		if(i > n) then
			break
		end
	    student['correct'][i] = val -- 正解不正解のフラグ
	end
	
	student['n_answers'] = n -- 回答の数
	return student -- 処理したstudentを返している
end



function DataAssistMatrix:getTestData()
	return self.testData
end

function DataAssistMatrix:getTrainData() -- trainAssistではこれを使っている
	return self.trainData
end

function DataAssistMatrix:getTestBatch()
	local batch = {}
	for id,answers in pairs(self.testData) do
		table.insert(batch, answers)
	end
	return batch;
end

