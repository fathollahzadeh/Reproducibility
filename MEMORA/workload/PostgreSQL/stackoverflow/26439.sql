WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        AVG(v.BountyAmount) AS AvgBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT a.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, u.DisplayName
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Author,
        rp.AnswerCount,
        rp.AvgBounty,
        STRING_AGG(t.TagName, ', ') AS AssociatedTags
    FROM 
        RankedPosts rp
    JOIN 
        LATERAL (
            SELECT 
                UNNEST(STRING_TO_ARRAY(rp.Tags, ',')) AS TagName
        ) t ON TRUE
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.LastActivityDate, rp.Author, rp.AnswerCount, rp.AvgBounty
),
PostStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Author,
        p.AnswerCount,
        p.AvgBounty,
        p.AssociatedTags,
        EXTRACT(EPOCH FROM cast('2024-10-01 12:34:56' as timestamp) - p.LastActivityDate) AS DaysSinceLastActivity
    FROM 
        TaggedPosts p
)
SELECT 
    ps.Title,
    ps.Author,
    ps.AnswerCount,
    ps.AvgBounty,
    ps.AssociatedTags,
    ps.DaysSinceLastActivity
FROM 
    PostStats ps
WHERE 
    ps.DaysSinceLastActivity < 604800 
ORDER BY 
    ps.AnswerCount DESC, ps.AvgBounty DESC
LIMIT 10;