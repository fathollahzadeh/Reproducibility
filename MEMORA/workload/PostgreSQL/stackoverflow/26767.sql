
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT STRING_AGG(b.Name, ', ') FROM Badges b WHERE b.UserId = p.OwnerUserId) AS UserBadges
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 
        AND Tags IS NOT NULL
    GROUP BY 
        TagName
),
RankedPosts AS (
    SELECT 
        ps.*, 
        ROW_NUMBER() OVER (ORDER BY Score DESC, AnswerCount DESC) AS Rank
    FROM 
        PostStats ps
)

SELECT 
    rp.Rank,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.UserBadges,
    ts.TagName,
    ts.PostCount
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON ts.TagName = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;
