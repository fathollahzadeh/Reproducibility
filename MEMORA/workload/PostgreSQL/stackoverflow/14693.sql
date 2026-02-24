
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(c.Score) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.QuestionsCount,
    us.AnswersCount,
    us.TotalCommentScore,
    us.UpVotes,
    us.DownVotes,
    COALESCE(FLOOR((CAST(us.UpVotes AS FLOAT) / NULLIF(us.DownVotes, 0)) * 100), 0) AS UpvoteDownvoteRatio
FROM 
    UserStats us
ORDER BY 
    us.PostCount DESC
LIMIT 100;
