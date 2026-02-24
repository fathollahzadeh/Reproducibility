WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        v.PostId
),
PostHistoryWithReason AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 
                      THEN 'Closed Reason: ' || (SELECT Name FROM CloseReasonTypes cr WHERE cr.Id = CAST(ph.Comment AS INT))
                      ELSE NULL END, ', ') AS CloseReasons,
        COUNT(CASE WHEN ph.PostId IS NOT NULL THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        phwr.CloseReasons,
        phwr.EditCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    LEFT JOIN 
        PostHistoryWithReason phwr ON rp.PostId = phwr.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.UpVotes,
    fp.DownVotes,
    fp.CloseReasons,
    fp.EditCount,
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'More Positive' 
        WHEN fp.UpVotes < fp.DownVotes THEN 'More Negative' 
        ELSE 'Neutral' 
    END AS Sentiment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC NULLS LAST
;