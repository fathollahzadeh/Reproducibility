
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT r.PostId) AS TotalPosts,
        SUM(r.AnswerCount) AS TotalAnswers,
        SUM(r.UpVotes) AS TotalUpVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalAnswers,
    u.TotalUpVotes,
    COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM 
    UserStats u
LEFT JOIN 
    Badges b ON u.UserId = b.UserId
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, u.TotalPosts, u.TotalAnswers, u.TotalUpVotes
ORDER BY 
    u.TotalUpVotes DESC
LIMIT 10;
