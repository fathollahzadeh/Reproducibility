
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id
),
PostPerformance AS (
    SELECT 
        Posts.Id,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        COALESCE(UserStats.PostCount, 0) AS UserPostCount,
        COALESCE(UserStats.QuestionCount, 0) AS UserQuestionCount,
        COALESCE(UserStats.AnswerCount, 0) AS UserAnswerCount
    FROM 
        Posts
    LEFT JOIN 
        UserStats ON Posts.OwnerUserId = UserStats.UserId
),
TopPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostPerformance
)

SELECT 
    Id,
    Title,
    CreationDate,
    Score,
    ViewCount,
    Rank
FROM 
    TopPosts
WHERE 
    Rank <= 100
ORDER BY 
    Rank;
