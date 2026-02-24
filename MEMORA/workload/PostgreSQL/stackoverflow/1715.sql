
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) OVER (PARTITION BY u.Location) AS AvgReputationByLocation,
        ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Location
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseHistoryRank
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.AvgReputationByLocation,
    ups.UserRank,
    COALESCE(pvc.VoteCount, 0) AS TotalVotes,
    COALESCE(pvc.UpVoteCount, 0) AS UpVotes,
    COALESCE(pvc.DownVoteCount, 0) AS DownVotes,
    ch.CloseReason,
    ch.CreationDate AS CloseDate
FROM UserPostStats ups
LEFT JOIN PostVoteCounts pvc ON ups.UserId = pvc.PostId
LEFT JOIN ClosedPostHistory ch ON ups.UserId = ch.PostId AND ch.CloseHistoryRank = 1
WHERE ups.PostCount > 0
ORDER BY ups.UserRank, ups.PostCount DESC
LIMIT 50;
