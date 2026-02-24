
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(b.Id) > 5 AND SUM(b.Class) > 5
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankByDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        tu.DisplayName AS TopUser
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId)
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    COALESCE(pd.UpVotes - pd.DownVotes, 0) AS NetVotes,
    pd.TopUser,
    CASE 
        WHEN pd.Score >= 10 THEN 'Popular'
        WHEN pd.CommentCount >= 5 THEN 'Engaging'
        ELSE 'Regular'
    END AS PostCategory
FROM 
    PostDetails pd
WHERE 
    pd.RankByDate = 1
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;
