WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COALESCE(AVG(u.Reputation), 0) AS AverageReputation
    FROM 
        Votes v
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        COALESCE(u.UpVotes, 0) AS UpVotes,
        COALESCE(u.DownVotes, 0) AS DownVotes,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.CommentTexts, '[No Comments]') AS CommentTexts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVotes u ON rp.PostId = u.PostId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    WHERE 
        rp.Rank <= 5
),
FinalSelection AS (
    SELECT 
        pd.*,
        CASE 
            WHEN pd.Score IS NULL THEN 'No Score Available'
            WHEN pd.UpVotes = 0 THEN 'No Upvotes'
            ELSE 'Interactive'
        END AS InteractionStatus
    FROM 
        PostDetails pd
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.ViewCount,
    fs.CreationDate,
    fs.Score,
    fs.UpVotes,
    fs.DownVotes,
    fs.CommentCount,
    fs.CommentTexts,
    fs.InteractionStatus
FROM 
    FinalSelection fs
WHERE 
    fs.CommentCount > 0 OR fs.UpVotes > 5
ORDER BY 
    fs.Score DESC NULLS LAST, 
    fs.ViewCount DESC;