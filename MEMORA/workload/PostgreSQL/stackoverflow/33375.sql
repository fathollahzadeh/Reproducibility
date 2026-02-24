
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(pa.Body, '') AS AcceptedAnswerBody
    FROM 
        Posts p
    LEFT JOIN 
        Posts pa ON p.AcceptedAnswerId = pa.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Comments c
    JOIN 
        Votes v ON c.PostId = v.PostId
    GROUP BY 
        c.PostId
),
TagStats AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag ON TRUE 
    JOIN 
        Tags t ON t.TagName = TRIM(tag)
    WHERE 
        t.Count > 5 
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ts.Tags,
        COALESCE(rp.AcceptedAnswerBody, 'None') AS AcceptedAnswerBody
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostStats ps ON rp.PostId = ps.PostId
    LEFT JOIN 
        TagStats ts ON rp.PostId = ts.PostId
    WHERE 
        rp.Rank <= 5 
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    CreationDate,
    Score,
    CommentCount,
    UpVotes,
    DownVotes,
    Tags,
    AcceptedAnswerBody
FROM 
    FinalResults
ORDER BY 
    Score DESC
LIMIT 10;
