
WITH UserStatistics AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(Comments.Score), 0) AS TotalCommentScore,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
),

PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        COALESCE(Users.DisplayName, 'Community') AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments WHERE Comments.PostId = Posts.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE Votes.PostId = Posts.Id AND Votes.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes WHERE Votes.PostId = Posts.Id AND Votes.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalCommentScore,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserStatistics
)

SELECT 
    TopUsers.Rank,
    TopUsers.DisplayName,
    TopUsers.PostCount,
    TopUsers.QuestionCount,
    TopUsers.AnswerCount,
    TopUsers.TotalCommentScore,
    TopUsers.TotalUpVotes,
    TopUsers.TotalDownVotes,
    PostStatistics.Title,
    PostStatistics.Score,
    PostStatistics.ViewCount,
    PostStatistics.CommentCount,
    PostStatistics.UpVoteCount,
    PostStatistics.DownVoteCount
FROM 
    TopUsers
LEFT JOIN 
    PostStatistics ON TopUsers.DisplayName = PostStatistics.OwnerDisplayName 
WHERE 
    TopUsers.Rank <= 10
ORDER BY 
    TopUsers.Rank;
