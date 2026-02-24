
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(v.VoteTypeId) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
), FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.Sentiment,
    u.DisplayName AS AuthorName,
    u.Reputation AS AuthorReputation,
    STRING_AGG(t.TagName, ',') AS Tags
FROM 
    FilteredPosts fp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
LEFT JOIN 
    LATERAL unnest(string_to_array(substring((SELECT Tags FROM Posts WHERE Id = fp.PostId), 2, length((SELECT Tags FROM Posts WHERE Id = fp.PostId))-2), '><')) AS t(TagName) ON t.TagName IS NOT NULL
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, 
    fp.CommentCount, fp.UpVotes, fp.DownVotes, 
    fp.Sentiment, u.DisplayName, u.Reputation
ORDER BY 
    fp.ViewCount DESC;
