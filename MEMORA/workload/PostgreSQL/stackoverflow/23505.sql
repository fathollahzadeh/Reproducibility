WITH RankedPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),

PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)

SELECT 
    rpd.PostId,
    rpd.Title,
    rpd.CreationDate,
    rpd.Score,
    rpd.AnswerCount,
    rpd.OwnerDisplayName,
    rpd.PostRank,
    pvd.UpVotes,
    pvd.DownVotes,
    pvd.TotalVotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN rpd.PostStatus = 'Closed' AND rpd.PostRank = 1 THEN 'Most Recent Closed Post'
        WHEN rpd.PostStatus = 'Open' AND rpd.PostRank = 1 THEN 'Most Recent Open Post'
        ELSE 'Other'
    END AS PostCategory
FROM RankedPostData rpd
JOIN PostVoteDetails pvd ON rpd.PostId = pvd.PostId
LEFT JOIN UserBadges ub ON rpd.OwnerDisplayName = (SELECT DisplayName FROM Users u WHERE u.Id = ub.UserId)
WHERE rpd.PostRank <= 5 
AND (rpd.Score > 10 OR pvd.TotalVotes > 20) 
ORDER BY rpd.CreationDate DESC, pvd.UpVotes DESC;