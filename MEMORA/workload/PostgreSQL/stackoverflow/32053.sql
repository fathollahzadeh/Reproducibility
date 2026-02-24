
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(u.UpVotes, 0)) AS TotalUpVotes,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        post.Id AS PostId,
        COUNT(ph.Id) AS EditHistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts post
    LEFT JOIN 
        PostHistory ph ON post.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        post.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    tuv.DisplayName AS TopUserName,
    tuv.TotalBounty,
    ih.EditHistoryCount,
    ih.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tuv ON rp.OwnerUserId = tuv.UserId
LEFT JOIN 
    PostHistoryStats ih ON rp.PostId = ih.PostId
WHERE 
    rp.Rank <= 5 
AND 
    (rp.Score > 10 OR rp.CommentCount > 5) 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
