
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(COALESCE(co.CommentCount, 0)) AS CommentsCount,
        SUM(COALESCE(v.VoteCount, 0)) AS VotesCount,
        COALESCE(MAX(p.CreationDate), '1970-01-01') AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY PostId) co ON p.Id = co.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
         FROM 
            Votes 
         GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostsCount, 
        AnswersCount, 
        QuestionsCount, 
        CommentsCount, 
        VotesCount, 
        LastActivityDate,
        RANK() OVER (ORDER BY PostsCount DESC) AS RankPosts,
        RANK() OVER (ORDER BY AnswersCount DESC) AS RankAnswers
    FROM 
        UserActivity
    WHERE 
        LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
)
SELECT 
    au.DisplayName,
    au.PostsCount,
    au.AnswersCount,
    au.QuestionsCount,
    au.CommentsCount,
    au.VotesCount,
    au.RankPosts,
    au.RankAnswers
FROM 
    ActiveUsers au
WHERE 
    au.RankPosts <= 10 OR au.RankAnswers <= 10
ORDER BY 
    au.RankPosts, au.RankAnswers;
