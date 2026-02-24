WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
        INNER JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVoteScore
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score + COALESCE(pc.CommentCount, 0) AS TotalEngagementScore,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COALESCE(pv.NetVoteScore, 0) AS NetVoteScore,
        CASE 
            WHEN tp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'New'
            WHEN tp.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' AND tp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '60 days' THEN 'Moderate'
            ELSE 'Old'
        END AS PostAgeCategory
    FROM 
        TopPosts tp
        LEFT JOIN PostComments pc ON tp.PostId = pc.PostId
        LEFT JOIN PostVotes pv ON tp.PostId = pv.PostId
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.NetVoteScore > 0 THEN 'Positive'
        WHEN fr.NetVoteScore < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    FinalResults fr
ORDER BY 
    fr.TotalEngagementScore DESC, 
    fr.NetVoteScore DESC;