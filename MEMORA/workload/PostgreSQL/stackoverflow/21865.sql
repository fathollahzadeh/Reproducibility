WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(u.Reputation, 0), 1) AS EffectiveReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Rank,
        COALESCE(ph.Comment, 'No history comment') AS LastEditComment,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 24 
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Rank, ph.Comment
),
FilteredPostDetails AS (
    SELECT 
        *,
        CASE 
            WHEN UpVotes > DownVotes THEN 'Popular'
            WHEN UpVotes < DownVotes THEN 'Controversial'
            ELSE 'Neutral'
        END AS Sentiment,
        CASE 
            WHEN ViewCount > 100 THEN 'Trending'
            ELSE 'Normal'
        END AS TrendingStatus
    FROM 
        PostDetails
    WHERE 
        LastEditComment LIKE '%helpful%' OR LastEditComment IS NULL
),
FinalOutput AS (
    SELECT
        f.PostId,
        f.Title,
        f.ViewCount,
        f.CommentCount,
        f.Sentiment,
        f.TrendingStatus,
        pht.Name AS LastEditType
    FROM 
        FilteredPostDetails f
    LEFT JOIN 
        PostHistory ph ON f.PostId = ph.PostId AND ph.PostHistoryTypeId IN (5, 6, 10)
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    ORDER BY 
        f.ViewCount DESC, f.CommentCount DESC
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    ViewCount IS NOT NULL OR CommentCount IS NOT NULL
UNION 
SELECT 
    NULL AS PostId,
    'Aggregate Count' AS Title,
    COUNT(*) AS ViewCount,
    SUM(CommentCount) AS CommentCount,
    NULL AS Sentiment,
    NULL AS TrendingStatus,
    NULL AS LastEditType
FROM 
    FinalOutput;