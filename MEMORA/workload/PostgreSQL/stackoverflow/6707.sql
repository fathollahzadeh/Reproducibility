
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        (PostCount + UpVotes - DownVotes) AS EngagementScore
    FROM 
        UserStats 
    WHERE 
        Reputation > 1000
    ORDER BY 
        EngagementScore DESC
    LIMIT 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    ORDER BY 
        p.CreationDate DESC
),
RecentComments AS (
    SELECT 
        c.Id AS CommentId,
        c.Text,
        c.CreationDate,
        p.Title AS PostTitle,
        u.DisplayName AS Commenter
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        c.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    COUNT(DISTINCT rc.CommentId) AS RecentCommentCount
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.DisplayName = rp.OwnerName
LEFT JOIN 
    RecentComments rc ON rc.Commenter = tu.DisplayName
GROUP BY 
    tu.DisplayName, tu.Reputation
ORDER BY 
    tu.Reputation DESC;
