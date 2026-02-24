WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName as OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) as Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) as UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) as DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) as AcceptedVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount,
    rp.OwnerDisplayName,
    vs.UpVotes,
    vs.DownVotes,
    vs.AcceptedVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    VoteStats vs ON rp.PostId = vs.PostId
WHERE 
    rp.Rank <= 100 
ORDER BY 
    rp.CreationDate DESC;