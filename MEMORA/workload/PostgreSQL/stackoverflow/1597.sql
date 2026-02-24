
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, pt.Name
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        SUM(CASE WHEN b.Class IN (1, 2, 3) THEN 1 ELSE 0 END) > 0
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Owner,
        rp.PostType,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        tu.UserId,
        tu.DisplayName AS TopUser,
        ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY rp.UpVotes DESC) AS VoteRank
    FROM 
        RecentPosts rp
    JOIN 
        TopUsers tu ON rp.Owner = tu.DisplayName
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.Owner,
    pe.PostType,
    pe.CommentCount,
    (pe.UpVotes - pe.DownVotes) AS NetVotes,
    COALESCE(pe.TopUser, 'No Top Contributor') AS TopContributor
FROM 
    PostEngagement pe
WHERE 
    pe.VoteRank = 1
ORDER BY 
    NetVotes DESC, pe.CreationDate DESC
LIMIT 10;
