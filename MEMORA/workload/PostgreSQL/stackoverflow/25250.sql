
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(tag.TagName, ',') ORDER BY p.ViewCount DESC) AS Rank,
        STRING_AGG(tag.TagName, ',') AS CombinedTags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
TopRankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CombinedTags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostWithVotes AS (
    SELECT 
        trp.Id AS PostId,
        trp.Title,
        trp.ViewCount,
        trp.Score,
        trp.CombinedTags,
        COALESCE(v.TotalUpvotes, 0) AS TotalUpvotes,
        COALESCE(v.TotalDownvotes, 0) AS TotalDownvotes
    FROM 
        TopRankedPosts trp
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON trp.Id = v.PostId
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.ViewCount,
    pwv.Score,
    pwv.CombinedTags,
    pwv.TotalUpvotes,
    pwv.TotalDownvotes,
    CASE 
        WHEN pwv.TotalUpvotes - pwv.TotalDownvotes > 0 THEN 'Positive'
        WHEN pwv.TotalUpvotes - pwv.TotalDownvotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PostWithVotes pwv
ORDER BY 
    pwv.TotalUpvotes DESC, pwv.Score DESC;
