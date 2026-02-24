
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
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
),

PostWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pvc.UpVoteCount,
        pvc.DownVoteCount,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
)

SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.OwnerDisplayName,
    pwv.CreationDate,
    pwv.Score,
    pwv.ViewCount,
    pwv.UpVoteCount,
    pwv.DownVoteCount,
    CASE 
        WHEN pwv.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostWithVotes pwv
WHERE 
    pwv.UpVoteCount IS NOT NULL
ORDER BY 
    pwv.Score DESC, 
    pwv.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
