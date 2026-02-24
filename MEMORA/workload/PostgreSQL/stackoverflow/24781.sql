WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
PostInteraction AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MAX(p.CreationDate) AS LastActivity,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY
        p.Id
),
RankedPosts AS (
    SELECT
        pi.PostId,
        pi.CommentCount,
        pi.TotalBounty,
        pi.LastActivity,
        pi.RelatedPostsCount,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN pi.TotalBounty > 0 THEN 'WithBounty' ELSE 'WithoutBounty' END ORDER BY pi.CommentCount DESC) AS Rank
    FROM
        PostInteraction pi
)
SELECT
    ur.DisplayName,
    ur.TotalBadgeClass,
    ur.TotalBadges,
    ur.QuestionCount,
    ur.AnswerCount,
    rp.PostId,
    rp.CommentCount,
    rp.TotalBounty,
    rp.LastActivity,
    rp.RelatedPostsCount,
    CASE WHEN rp.TotalBounty > 0 THEN 'Bounty' ELSE 'No Bounty' END AS BountyStatus
FROM
    UserReputation ur
JOIN
    RankedPosts rp ON ur.UserId = (
        SELECT
            p.OwnerUserId
        FROM
            Posts p
        WHERE
            p.Id = rp.PostId
    )
WHERE
    rp.Rank <= 3
    AND (
        SELECT COUNT(*)
        FROM Posts p
        WHERE p.OwnerUserId = ur.UserId AND p.Score IS NOT NULL
    ) > 5
ORDER BY
    ur.TotalBadgeClass DESC,
    rp.CommentCount DESC;