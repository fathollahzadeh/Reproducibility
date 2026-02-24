
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.AcceptedAnswerId, p.Tags
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.HasAcceptedAnswer,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.CreationDate,
    fp.HasAcceptedAnswer,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    CASE 
        WHEN fp.HasAcceptedAnswer = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS AcceptedAnswerStatus
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ViewCount DESC, 
    fp.UpVotes DESC
LIMIT 50;
