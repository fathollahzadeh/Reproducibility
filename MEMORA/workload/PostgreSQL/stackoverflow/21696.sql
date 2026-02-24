WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT SUM(v.BountyAmount) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 8), 0) AS TotalBounty
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
          AND p.Score > 0
),
PostWithMaxViews AS (
    SELECT 
        PostId,
        MAX(ViewCount) AS MaxViewCount
    FROM 
        RankedPosts
    GROUP BY 
        PostId
),
EligiblePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Rank,
        pwv.MaxViewCount
    FROM 
        RankedPosts rp
    JOIN 
        PostWithMaxViews pwv ON rp.PostId = pwv.PostId
    WHERE 
        rp.Rank <= 5 
        AND rp.TotalBounty >= 50
),
VotesStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        AVG(BountyAmount) AS AvgBounty 
    FROM 
        Votes v
    GROUP BY 
        PostId
),
BountyQualifiedPosts AS (
    SELECT 
        ep.*,
        vs.UpVotesCount,
        vs.DownVotesCount,
        vs.AvgBounty
    FROM 
        EligiblePosts ep
    LEFT JOIN 
        VotesStats vs ON ep.PostId = vs.PostId
    WHERE 
        ep.MaxViewCount > 1000
)
SELECT 
    bqp.Title,
    bqp.Score,
    bqp.MaxViewCount,
    bqp.UpVotesCount,
    bqp.DownVotesCount,
    COALESCE(bqp.AvgBounty, 0) AS AvgBounty,
    CASE 
        WHEN bqp.UpVotesCount > bqp.DownVotesCount THEN 'Positive'
        WHEN bqp.UpVotesCount < bqp.DownVotesCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    BountyQualifiedPosts bqp
WHERE 
    bqp.MaxViewCount IS NOT NULL
ORDER BY 
    bqp.Score DESC, 
    bqp.Title ASC;