
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        u.DisplayName AS Owner,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id 
    LEFT JOIN 
        Votes v ON v.PostId = p.Id 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Tags, p.Body
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Body,
        rp.Owner,
        rp.AnswerCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
)
SELECT 
    fp.Title,
    fp.Owner,
    fp.AnswerCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    ARRAY_LENGTH(string_to_array(fp.Tags, '><'), 1) AS TagCount, 
    LENGTH(fp.Body) AS BodyLength, 
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive' 
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS Sentiment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVotes DESC, 
    fp.AnswerCount DESC
FETCH FIRST 10 ROWS ONLY;
