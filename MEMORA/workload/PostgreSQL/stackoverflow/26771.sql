WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year') 
),
UserInteractions AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Comments c
    LEFT JOIN 
        Votes v ON c.PostId = v.PostId
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        ui.CommentCount AS InteractionCommentCount,
        ui.UpVoteCount,
        ui.DownVoteCount,
        ARRAY_LENGTH(STRING_TO_ARRAY(rp.Tags, ','), 1) AS TagCount
    FROM 
        RankedPosts rp
    JOIN 
        UserInteractions ui ON rp.PostId = ui.PostId
    WHERE 
        rp.TagRank <= 5 
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.InteractionCommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.TagCount
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC
LIMIT 100;