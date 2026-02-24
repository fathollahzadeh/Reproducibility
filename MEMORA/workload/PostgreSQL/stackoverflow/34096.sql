
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'  
        AND p.PostTypeId IN (1, 2)  
), 
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM 
        Votes 
    GROUP BY 
        PostId
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments 
    GROUP BY 
        PostId
), 
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        rp.RankScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.CreationDate,
    ad.Score,
    ad.ViewCount,
    ad.AnswerCount,
    ad.OwnerDisplayName,
    ad.UpVotes,
    ad.DownVotes,
    ad.CommentCount,
    CASE 
        WHEN ad.Score > 0 THEN 'Popular'
        WHEN ad.Score < 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END AS PopularityStatus,
    CASE 
        WHEN ad.UpVotes > ad.DownVotes THEN 'More Upvotes'
        WHEN ad.UpVotes < ad.DownVotes THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteSummary
FROM 
    AggregatedData ad
WHERE 
    ad.RankScore <= 10  
ORDER BY 
    ad.CreationDate DESC;
