
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryInfo AS (
    SELECT 
        p.Id AS PostId, 
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
FinalResult AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ub.BadgeCount,
        ub.BadgeNames,
        ph.LastEdited,
        ph.CloseReopenCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostHistoryInfo ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        VoteSummary vs ON rp.PostId = vs.PostId
    WHERE 
        rp.Rank = 1
        AND rp.ViewCount > 100
)

SELECT 
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.BadgeCount,
    fr.BadgeNames,
    fr.LastEdited,
    fr.CloseReopenCount,
    CASE 
        WHEN fr.UpVotes > fr.DownVotes THEN 'Positive' 
        WHEN fr.UpVotes < fr.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    FinalResult fr
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts sub 
        WHERE sub.AcceptedAnswerId = fr.PostId
    )
ORDER BY 
    fr.Score DESC,
    fr.ViewCount DESC;
