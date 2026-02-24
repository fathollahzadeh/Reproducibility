WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
        string_agg(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        (SELECT
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
            Id
        FROM
            Posts) t ON p.Id = t.Id
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
PostStatistics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Tags,
        (rp.UpVotes - rp.DownVotes) AS NetVotes
    FROM
        RecentPosts rp
)
SELECT
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.NetVotes,
    CASE 
        WHEN ps.NetVotes > 0 THEN 'Positive'
        WHEN ps.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM
    PostStatistics ps
ORDER BY
    ps.NetVotes DESC,
    ps.ViewCount DESC
LIMIT 10;