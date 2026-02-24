
WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostDetails AS (
    SELECT 
        rps.PostId,
        rps.Title,
        rps.ViewCount,
        rps.Score,
        rps.CommentCount,
        p.OwnerUserId,
        tu.DisplayName AS OwnerDisplayName,
        tu.UserRank
    FROM 
        RecentPostStats rps
    INNER JOIN 
        Posts p ON rps.PostId = p.Id
    LEFT JOIN 
        TopUsers tu ON p.OwnerUserId = tu.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    COALESCE(pd.OwnerDisplayName, 'Community User') AS OwnerDisplayName,
    pd.UserRank,
    CASE 
        WHEN pd.UserRank IS NOT NULL THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 5
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
