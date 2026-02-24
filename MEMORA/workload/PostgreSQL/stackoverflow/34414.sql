
WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AnswerCount,
        NULL AS ParentPostId
    FROM Posts p
    WHERE p.PostTypeId = 1 
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.AnswerCount,
        p.Id AS ParentPostId
    FROM Posts a
    INNER JOIN Posts p ON a.ParentId = p.Id
    WHERE p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
VoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title AS PostTitle,
    u.DisplayName AS OwnerDisplayName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(vc.UpVotes, 0) AS UpVotes,
    COALESCE(vc.DownVotes, 0) AS DownVotes,
    rp.AnswerCount AS QuestionAnswerCount,
    rp.CreationDate,
    CASE 
        WHEN rp.ParentPostId IS NOT NULL THEN 'Answer'
        ELSE 'Question'
    END AS PostType,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY rp.CreationDate DESC) AS UserPostRank
FROM RecursivePosts rp
LEFT JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN VoteCounts vc ON rp.Id = vc.PostId
WHERE 
    rp.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
    (ub.TotalBadges IS NULL OR ub.TotalBadges > 5) 
ORDER BY 
    rp.CreationDate DESC, 
    UpVotes DESC;
