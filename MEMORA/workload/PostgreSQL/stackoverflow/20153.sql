WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
         AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
         AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(rp.UpVotes - rp.DownVotes, 0) AS VoteBalance,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'Highly Viewed' 
            ELSE 'Regular Post' 
        END AS PostType,
        ROW_NUMBER() OVER (ORDER BY COALESCE(rp.UpVotes - rp.DownVotes, 0) DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph 
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name LIKE '%Close%'
    GROUP BY 
        ph.PostId
)
SELECT 
    pd.PostID,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.VoteBalance,
    pd.PostType,
    cp.CloseReasons,
    (CASE 
        WHEN pd.PopularityRank <= 10 THEN 'Top Posts'
        ELSE 'Other Posts'
    END) AS PostRankCategory
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPosts cp ON pd.PostID = cp.PostId
WHERE 
    pd.VoteBalance > 0
ORDER BY 
    pd.VoteBalance DESC, 
    pd.ViewCount DESC NULLS LAST;