WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
), 
TopScoredPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
), 
PostVoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    tsp.PostId,
    tsp.Title,
    tsp.Tags,
    tsp.CreationDate,
    tsp.Score,
    tsp.ViewCount,
    tsp.AnswerCount,
    tsp.OwnerName,
    COALESCE(pvc.UpVoteCount, 0) AS UpVotes,
    COALESCE(pvc.DownVoteCount, 0) AS DownVotes
FROM 
    TopScoredPosts tsp
LEFT JOIN 
    PostVoteCounts pvc ON tsp.PostId = pvc.PostId
ORDER BY 
    tsp.ViewCount DESC, tsp.Score DESC;