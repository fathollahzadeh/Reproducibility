
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY UpVotes - DownVotes DESC, CommentCount DESC) AS PopularityRank
    FROM 
        RankedPosts
)
SELECT 
    t.PostId,
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.UpVotes,
    t.DownVotes,
    t.CommentCount,
    t.CloseCount,
    RANK() OVER (ORDER BY t.PopularityRank) AS OverallRank
FROM 
    TopPosts t
WHERE 
    t.PostRank = 1
ORDER BY 
    OverallRank;
