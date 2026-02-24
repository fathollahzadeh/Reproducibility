WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        MAX(b.Class) OVER (PARTITION BY p.OwnerUserId) AS MaxBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
),

PostAnalytics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel,
        COALESCE(rp.MaxBadgeClass, 0) AS UserBadgeClass
    FROM 
        RankedPosts rp 
    WHERE 
        rp.ScoreRank <= 10 
),

InvalidVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId NOT IN (2, 3) THEN 1 ELSE 0 END) AS InvalidVoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),

FinalResult AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.Score,
        pa.DiscussionLevel,
        pa.UserBadgeClass,
        COALESCE(iv.InvalidVoteCount, 0) AS InvalidVoteCount
    FROM 
        PostAnalytics pa
    LEFT JOIN 
        InvalidVotes iv ON pa.PostId = iv.PostId
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.DiscussionLevel,
    fr.UserBadgeClass,
    CASE 
        WHEN fr.InvalidVoteCount > 5 THEN 'Needs Attention' 
        ELSE 'Normal'
    END AS PostStatus
FROM 
    FinalResult fr
WHERE 
    fr.UserBadgeClass = 1 
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC;