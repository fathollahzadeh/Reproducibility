
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(c.Score) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(EXTRACT(EPOCH FROM (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - p.CreationDate)) / 60) AS AvgPostAgeInMinutes,
        MAX(p.CreationDate) AS LastActivityDate
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
),
PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ua.DisplayName AS UserDisplayName,
        ua.UserId,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalCommentScore,
        ua.TotalUpVotes,
        ua.TotalDownVotes
    FROM 
        PostScore ps
    JOIN 
        UserActivity ua ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)
    WHERE 
        ps.ScoreRank <= 100
)
SELECT 
    pp.UserDisplayName,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.TotalPosts,
    pp.TotalQuestions,
    pp.TotalAnswers,
    pp.TotalCommentScore,
    pp.TotalUpVotes,
    pp.TotalDownVotes
FROM 
    TopPosts pp
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
