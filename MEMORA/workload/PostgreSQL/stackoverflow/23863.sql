
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteCount) AS AvgUserVote
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
                SELECT 
                    PostId, COUNT(*) AS VoteCount
                FROM 
                    Votes 
                WHERE 
                    VoteTypeId IN (2, 3) 
                GROUP BY 
                    PostId
               ) v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(t.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes t ON CAST(ph.Comment AS INTEGER) = t.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
FinalPosts AS (
    SELECT 
        rp.*,
        COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.PostRank = 1 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.AvgUserVote,
    fp.CloseReasons,
    CASE 
        WHEN fp.CloseReasons IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN fp.ViewCount IS NULL OR fp.Score <= 0 THEN 'Needs Attention'
        WHEN fp.Score > 100 THEN 'Popular'
        ELSE 'Regular'
    END AS PostClassification
FROM 
    FinalPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount ASC; 
