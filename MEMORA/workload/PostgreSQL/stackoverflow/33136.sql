
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostHistoryCount AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName AS Author,
        ua.PostCount,
        COALESCE(phc.EditCount, 0) AS EditCount,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    JOIN 
        UserActivity ua ON ua.UserId = u.Id
    LEFT JOIN 
        PostHistoryCount phc ON phc.PostId = rp.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.PostCount,
    tp.EditCount,
    tp.Score,
    tp.ViewCount,
    ROUND(CAST(tp.Score AS DECIMAL) / NULLIF(tp.ViewCount, 0), 2) AS ScoreToViewRatio
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
