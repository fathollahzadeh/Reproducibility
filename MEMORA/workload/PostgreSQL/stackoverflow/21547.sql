WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
        AND u.Reputation > 0
), 
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId
), 
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.CommentCount DESC) AS UserPostRank,
        pt.Name AS PostType,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        PostSummary ps
    JOIN PostTypes pt ON ps.PostTypeId = pt.Id
    LEFT JOIN Posts p ON ps.PostId = p.Id
    LEFT JOIN LATERAL (
        SELECT 
            SUBSTRING(pb.Tags, 2, LENGTH(pb.Tags) - 2) AS Tags
        FROM 
            Posts pb
        WHERE 
            pb.Id = ps.PostId
    ) AS tagData ON TRUE
    LEFT JOIN UNNEST(string_to_array(tagData.Tags, '><')) AS t(TagName) ON TRUE
    GROUP BY 
        ps.PostId, ps.OwnerUserId, ps.CommentCount, ps.UpVoteCount, ps.DownVoteCount, ps.TotalBounty, pt.Name
)

SELECT 
    u.DisplayName,
    u.Reputation,
    p.PostId,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.TotalBounty,
    p.PostType,
    p.Tags,
    CASE 
        WHEN p.CommentCount IS NULL THEN 'No comments yet'
        ELSE CONCAT('This post has ', p.CommentCount, ' comments.')
    END AS CommentStatus,
    CASE 
        WHEN u.UserId IS NULL THEN 'User not found'
        ELSE (SELECT Name FROM PostHistoryTypes WHERE Id = (SELECT MAX(PostHistoryTypeId) FROM PostHistory WHERE PostId = p.PostId))
    END AS LastActionType
FROM 
    RankedUsers u
JOIN 
    PostDetails p ON u.UserId = p.OwnerUserId
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank, p.CommentCount DESC;