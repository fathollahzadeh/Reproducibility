WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, 0) AS IsAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),

VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

ActivePosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.DisplayName,
        ub.BadgeCount,
        vs.UpVotes,
        vs.DownVotes,
        vs.CloseVotes,
        CASE 
            WHEN vs.CloseVotes > 0 THEN 'Closed'
            WHEN rp.IsAcceptedAnswer <> 0 THEN 'Answered'
            ELSE 'Unanswered'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.DisplayName = ub.UserId::text 
    LEFT JOIN 
        VoteSummary vs ON rp.Id = vs.PostId
    WHERE 
        rp.Rank <= 5
)

SELECT 
    ap.Id,
    ap.Title,
    ap.Score,
    ap.ViewCount,
    ap.DisplayName,
    COALESCE(ap.BadgeCount, 0) AS GoldBadgeCount,
    ap.UpVotes,
    ap.DownVotes,
    ap.CloseVotes,
    ap.PostStatus,
    CASE 
        WHEN ap.Score IS NULL OR ap.ViewCount IS NULL THEN 'Information Insufficient'
        ELSE 'Data Available'
    END AS DataStatus
FROM 
    ActivePosts ap
WHERE 
    (ap.UpVotes - ap.DownVotes) > 5
OR 
    (ap.CloseVotes = 0 AND ap.PostStatus = 'Unanswered')
ORDER BY 
    ap.Score DESC NULLS LAST, ap.ViewCount DESC;