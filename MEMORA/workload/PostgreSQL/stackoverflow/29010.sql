WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS ApprovedAnswer,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.AcceptedAnswerId
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.ApprovedAnswer,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        SPLIT_PART(rp.Tags, '>', 2) AS PrimaryTag 
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PrimaryTag,
    COUNT(tp.PostId) AS TagPostCount,
    AVG(tp.ViewCount) AS AvgViewCount,
    AVG(tp.AnswerCount) AS AvgAnswerCount,
    SUM(tp.UpVotes) AS TotalUpVotes,
    SUM(tp.DownVotes) AS TotalDownVotes,
    MAX(tp.CreationDate) AS LastPostDate
FROM 
    TaggedPosts tp
WHERE 
    tp.ViewCount > 100 
GROUP BY 
    tp.PrimaryTag
ORDER BY 
    TagPostCount DESC;